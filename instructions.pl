#############################################################################
# mubench - low-level x86 instruction benchmark
# Copyright (C) 2005-2006 Alex Izvorski <aizvorski@gmail.com>
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111, USA.
#############################################################################

@instructions = 
(
#############################################################################
# XOP and FMA4

'VFMADDPD xmm, xmm, xmm, xmm',
'VFMADDPS xmm, xmm, xmm, xmm',
'VFMADDSD xmm, xmm, xmm, xmm',
'VFMADDSS xmm, xmm, xmm, xmm',
'VFMADDSUBPD xmm, xmm, xmm, xmm',
'VFMADDSUBPS xmm, xmm, xmm, xmm',
'VFMSUBADDPD xmm, xmm, xmm, xmm',
'VFMSUBADDPS xmm, xmm, xmm, xmm',
'VFMSUBPD xmm, xmm, xmm, xmm',
'VFMSUBPS xmm, xmm, xmm, xmm',
'VFMSUBSD xmm, xmm, xmm, xmm',
'VFMSUBSS xmm, xmm, xmm, xmm',
'VFNMADDPD xmm, xmm, xmm, xmm',
'VFNMADDPS xmm, xmm, xmm, xmm',
'VFNMADDSD xmm, xmm, xmm, xmm',
'VFNMADDSS xmm, xmm, xmm, xmm',
'VFNMSUBPD xmm, xmm, xmm, xmm',
'VFNMSUBPS xmm, xmm, xmm, xmm',
'VFNMSUBSD xmm, xmm, xmm, xmm',
'VFNMSUBSS xmm, xmm, xmm, xmm',
'VFRCZPD xmm, xmm',
'VFRCZPS xmm, xmm',
'VFRCZSD xmm, xmm',
'VFRCZSS xmm, xmm',
'VPCMOV xmm, xmm, xmm, xmm',
'VPCOMB xmm, xmm, xmm, imm8',
'VPCOMD xmm, xmm, xmm, imm8',
'VPCOMQ xmm, xmm, xmm, imm8',
'VPCOMUB xmm, xmm, xmm, imm8',
'VPCOMUD xmm, xmm, xmm, imm8',
'VPCOMUQ xmm, xmm, xmm, imm8',
'VPCOMUW xmm, xmm, xmm, imm8',
'VPCOMW xmm, xmm, xmm, imm8',
'VPHADDBD xmm, xmm',
'VPHADDBQ xmm, xmm',
'VPHADDBW xmm, xmm',
'VPHADDDQ xmm, xmm',
'VPHADDUBD xmm, xmm',
'VPHADDUBQ xmm, xmm',
'VPHADDUBW xmm, xmm',
'VPHADDUDQ xmm, xmm',
'VPHADDUWD xmm, xmm',
'VPHADDUWQ xmm, xmm',
'VPHADDWD xmm, xmm',
'VPHADDWQ xmm, xmm',
'VPHSUBBW xmm, xmm',
'VPHSUBDQ xmm, xmm',
'VPHSUBWD xmm, xmm',
'VPPERM xmm, xmm, xmm, xmm',
'VPERMILPD xmm, xmm, xmm, xmm',
'VPERMILPS xmm, xmm, xmm, xmm',
'VPMACSDD xmm, xmm, xmm, xmm',
'VPMACSDQH xmm, xmm, xmm, xmm',
'VPMACSDQL xmm, xmm, xmm, xmm',
'VPMACSSDD xmm, xmm, xmm, xmm',
'VPMACSSDQH xmm, xmm, xmm, xmm',
'VPMACSSDQL xmm, xmm, xmm, xmm',
'VPMACSSWD xmm, xmm, xmm, xmm',
'VPMACSSWW xmm, xmm, xmm, xmm',
'VPMACSWD xmm, xmm, xmm, xmm',
'VPMACSWW xmm, xmm, xmm, xmm',
'VPMADCSSWD xmm, xmm, xmm, xmm',
'VPMADCSWD xmm, xmm, xmm, xmm',
'VPROTB xmm, xmm, xmm',
'VPROTD xmm, xmm, xmm',
'VPROTQ xmm, xmm, xmm',
'VPROTW xmm, xmm, xmm',
'VPSHAB xmm, xmm, xmm',
'VPSHAD xmm, xmm, xmm',
'VPSHAQ xmm, xmm, xmm',
'VPSHAW xmm, xmm, xmm',
'VPSHLB xmm, xmm, xmm',
'VPSHLD xmm, xmm, xmm',
'VPSHLQ xmm, xmm, xmm',
'VPSHLW xmm, xmm, xmm',

#############################################################################
# SSE4.1 (aka Penryn New Instructions)
'MPSADBW xmm, xmm, imm8',
'PHMINPOSUW xmm, xmm',
'PMULLD xmm, xmm',
'PMULDQ xmm, xmm',
'BLENDPS xmm, xmm, imm8',
'BLENDPD xmm, xmm, imm8',
'PBLENDW xmm, xmm, imm8',
'BLENDVPS xmm, xmm, xmm0',
'BLENDVPD xmm, xmm, xmm0',
'PBLENDVB xmm, xmm, xmm0',
'PMAXSB xmm, xmm',
'PMINSB xmm, xmm',
'PMAXUW xmm, xmm',
'PMINUW xmm, xmm',
'PMAXSD xmm, xmm',
'PMINSD xmm, xmm',
'PMAXUD xmm, xmm',
'PMINUD xmm, xmm',
'INSERTPS xmm, xmm, imm8',
'PINSRB xmm, r32, imm8',
'PINSRD xmm, r32, imm8',
'PINSRQ xmm, r64, imm8',
'EXTRACTPS r32, xmm, imm8',
'PEXTRB r32, xmm, imm8',
'PEXTRD r32, xmm, imm8',
'PEXTRQ r64, xmm, imm8',
'PMOVSXBW xmm, xmm',
'PMOVZXBW xmm, xmm',
'PMOVSXBD xmm, xmm',
'PMOVZXBD xmm, xmm',
'PMOVSXBQ xmm, xmm',
'PMOVZXBQ xmm, xmm',
'PMOVSXWD xmm, xmm',
'PMOVZXWD xmm, xmm',
'PMOVSXWQ xmm, xmm',
'PMOVZXWQ xmm, xmm',
'PMOVSXDQ xmm, xmm',
'PMOVZXDQ xmm, xmm',
'PTEST xmm, xmm',
'PCMPEQQ xmm, xmm',
'PACKUSDW xmm, xmm',
#'MOVNTDQA mem128, xmm',

# SSE4.1 float
'DPPS xmm, xmm, imm8',
'DPPD xmm, xmm, imm8',
'ROUNDPS xmm, xmm, imm8',
'ROUNDSS xmm, xmm, imm8',
'ROUNDPD xmm, xmm, imm8',
'ROUNDSD xmm, xmm, imm8',

#############################################################################
# SSSE3 (aka Merom New Instructions)
'PSIGNB xmm, xmm',
'PSIGNW xmm, xmm',
'PSIGND xmm, xmm',
'PSHUFB xmm, xmm',
'PMULHRSW xmm, xmm',
'PMADDUBSW xmm, xmm',
'PHSUBW xmm, xmm',
'PHSUBSW xmm, xmm',
'PHSUBD xmm, xmm',
'PHADDW xmm, xmm',
'PHADDSW xmm, xmm',
'PHADDD xmm, xmm',
'PALIGNR xmm, xmm, imm8',
'PABSB xmm, xmm',
'PABSW xmm, xmm',
'PABSD xmm, xmm',

# SSE2 int64
'PSIGNB mm, mm',
'PSIGNW mm, mm',
'PSIGND mm, mm',
'PSHUFB mm, mm',
'PMULHRSW mm, mm',
'PMADDUBSW mm, mm',
'PHSUBW mm, mm',
'PHSUBSW mm, mm',
'PHSUBD mm, mm',
'PHADDW mm, mm',
'PHADDSW mm, mm',
'PHADDD mm, mm',
'PALIGNR mm, mm, imm8',
'PABSB mm, mm',
'PABSW mm, mm',
'PABSD mm, mm',

#############################################################################
# Source: http://www.intel.com/design/pentium4/manuals/index_new.htm
# and ftp://download.intel.com/design/Pentium4/manuals/24896613.pdf

# SSE3 single/double (aka Prescott New Instructions)
'ADDSUBPD xmm, xmm',
'ADDSUBPS xmm, xmm',
'HADDPD xmm, xmm',
'HADDPS xmm, xmm',
'HSUBPD xmm, xmm',
'HSUBPS xmm, xmm',
'MOVDDUP xmm, xmm',
'MOVSHDUP xmm, xmm',
'MOVSLDUP xmm, xmm',
#'LDDQU xmm, mem128/mem128u',
#'FISTTP',
#'MONITOR',
#'MWAIT',

# SSE2 int128
'CVTDQ2PS xmm, xmm',
'CVTPS2DQ xmm, xmm',
'CVTTPS2DQ xmm, xmm',
'MOVD xmm, r32',
'MOVD r32, xmm',
'MOVDQA xmm, xmm',
#'MOVDQU xmm, xmm/mem128u',
'MOVDQ2Q mm, xmm',
'MOVQ2DQ xmm, mm',
'MOVQ xmm, xmm',
'PACKSSWB xmm, xmm',
'PACKSSDW xmm, xmm',
'PACKUSWB xmm, xmm',
'PADDB xmm, xmm',
'PADDW xmm, xmm',
'PADDD xmm, xmm',
'PADDSB xmm, xmm',
'PADDSW xmm, xmm',
'PADDUSB xmm, xmm',
'PADDUSW xmm, xmm',
'PADDQ xmm, xmm',
'PSUBQ xmm, xmm',
'PAND xmm, xmm',
'PANDN xmm, xmm',
'PAVGB xmm, xmm',
'PAVGW xmm, xmm',
'PCMPEQB xmm, xmm',
'PCMPEQD xmm, xmm',
'PCMPEQW xmm, xmm',
'PCMPGTB xmm, xmm',
'PCMPGTD xmm, xmm',
'PCMPGTW xmm, xmm',
'PEXTRW r32, xmm, imm8',
'PINSRW xmm, r32, imm8',
'PMADDWD xmm, xmm',
'PMAXUB xmm, xmm',
'PMAXSW xmm, xmm',
'PMINUB xmm, xmm',
'PMINSW xmm, xmm',
'PMOVMSKB r32, xmm',
'PMULHUW xmm, xmm',
'PMULHW xmm, xmm',
'PMULLW xmm, xmm',
'PMULUDQ xmm, xmm',
'POR xmm, xmm',
'PSADBW xmm, xmm',
'PSHUFD xmm, xmm, imm8',
'PSHUFHW xmm, xmm, imm8',
'PSHUFLW xmm, xmm, imm8',
'PSLLDQ xmm, imm8',
'PSLLW xmm, xmm/imm8',
'PSLLD xmm, xmm/imm8',
'PSLLQ xmm, xmm/imm8',
'PSRAW xmm, xmm/imm8',
'PSRAD xmm, xmm/imm8',
'PSRLDQ xmm, imm8',
'PSRLW xmm, xmm/imm8',
'PSRLD xmm, xmm/imm8',
'PSRLQ xmm, xmm/imm8',
'PSUBB xmm, xmm',
'PSUBW xmm, xmm',
'PSUBD xmm, xmm',
'PSUBSB xmm, xmm',
'PSUBSW xmm, xmm',
'PSUBUSB xmm, xmm',
'PSUBUSW xmm, xmm',
'PUNPCKHBW xmm, xmm',
'PUNPCKHWD xmm, xmm',
'PUNPCKHDQ xmm, xmm',
'PUNPCKHQDQ xmm, xmm',
'PUNPCKLBW xmm, xmm',
'PUNPCKLWD xmm, xmm',
'PUNPCKLDQ xmm, xmm',
'PUNPCKLQDQ xmm, xmm',
'PXOR xmm, xmm',

# SSE2 int64
'PADDQ mm, mm',
'PSUBQ mm, mm',
'PMULUDQ mm, mm',

# SSE2 double
'ADDPD xmm, xmm',
'ADDSD xmm, xmm',
'ANDNPD xmm, xmm',
'ANDPD xmm, xmm',
'CMPPD xmm, xmm, imm8',
'CMPSD xmm, xmm, imm8',
'COMISD xmm, xmm',
'CVTDQ2PD xmm, xmm',
'CVTPD2PI mm, xmm',
'CVTPD2DQ xmm, xmm',
'CVTPD2PS xmm, xmm',
'CVTPI2PD xmm, mm',
'CVTPS2PD xmm, xmm',
'CVTSD2SI r32, xmm',
'CVTSD2SS xmm, xmm',
'CVTSI2SD xmm, r32',
'CVTSS2SD xmm, xmm',
'CVTTPD2PI mm, xmm',
'CVTTPD2DQ xmm, xmm',
'CVTTSD2SI r32, xmm',
'DIVPD xmm, xmm',
'DIVSD xmm, xmm',
'MAXPD xmm, xmm',
'MAXSD xmm, xmm',
'MINPD xmm, xmm',
'MINSD xmm, xmm',
'MOVAPD xmm, xmm',
'MOVMSKPD r32, xmm',
'MOVSD xmm, xmm',
'MOVUPD xmm, xmm',
'MULPD xmm, xmm',
'MULSD xmm, xmm',
'ORPD xmm, xmm',
'SHUFPD xmm, xmm, imm8',
'SQRTPD xmm, xmm',
'SQRTSD xmm, xmm',
'SUBPD xmm, xmm',
'SUBSD xmm, xmm',
'UCOMISD xmm, xmm',
'UNPCKHPD xmm, xmm',
'UNPCKLPD xmm, xmm',
'XORPD xmm, xmm',

#############################################################################
# SSE single
'ADDPS xmm, xmm',
'ADDSS xmm, xmm',
'ANDNPS xmm, xmm',
'ANDPS xmm, xmm',
'CMPPS xmm, xmm, imm8',
'CMPSS xmm, xmm, imm8',
'COMISS xmm, xmm',
'CVTPI2PS xmm, mm',
'CVTPS2PI mm, xmm',
'CVTSI2SS xmm, r32',
'CVTSS2SI r32, xmm',
'CVTTPS2PI mm, xmm',
'CVTTSS2SI r32, xmm',
'DIVPS xmm, xmm',
'DIVSS xmm, xmm',
'MAXPS xmm, xmm',
'MAXSS xmm, xmm',
'MINPS xmm, xmm',
'MINSS xmm, xmm',
'MOVAPS xmm, xmm',
'MOVHLPS xmm, xmm',
'MOVLHPS xmm, xmm',
'MOVMSKPS r32, xmm',
'MOVSS xmm, xmm',
'MOVUPS xmm, xmm',
'MULPS xmm, xmm',
'MULSS xmm, xmm',
'ORPS xmm, xmm',
'RCPPS xmm, xmm',
'RCPSS xmm, xmm',
'RSQRTPS xmm, xmm',
'RSQRTSS xmm, xmm',
'SHUFPS xmm, xmm, imm8',
'SQRTPS xmm, xmm',
'SQRTSS xmm, xmm',
'SUBPS xmm, xmm',
'SUBSS xmm, xmm',
'UCOMISS xmm, xmm',
'UNPCKHPS xmm, xmm',
'UNPCKLPS xmm, xmm',
'XORPS xmm, xmm',
#'FXRSTOR',
#'FXSAVE',

# SSE int64
'PAVGB mm, mm',
'PAVGW mm, mm',
'PEXTRW r32, mm, imm8',
'PINSRW mm, r32, imm8',
'PMAXUB mm, mm',
'PMAXSW mm, mm',
'PMINUB mm, mm',
'PMINSW mm, mm',
'PMOVMSKB r32, mm',
'PMULHUW mm, mm',
'PSADBW mm, mm',
'PSHUFW mm, mm, imm8',

#############################################################################
# MMX
'MOVD mm, r32',
'MOVD r32, mm',
'MOVQ mm, mm',
'PACKSSWB mm, mm',
'PACKSSDW mm, mm',
'PACKUSWB mm, mm',
'PADDB mm, mm',
'PADDW mm, mm',
'PADDD mm, mm',
'PADDSB mm, mm',
'PADDSW mm, mm',
'PADDUSB mm, mm',
'PADDUSW mm, mm',
'PAND mm, mm',
'PANDN mm, mm',
'PCMPEQB mm, mm',
'PCMPEQD mm, mm',
'PCMPEQW mm, mm',
'PCMPGTB mm, mm',
'PCMPGTD mm, mm',
'PCMPGTW mm, mm',
'PMADDWD mm, mm',
'PMULHW mm, mm',
'PMULLW mm, mm',
'POR mm, mm',
'PSLLQ mm, mm/imm8',
'PSLLW mm, mm/imm8',
'PSLLD mm, mm/imm8',
'PSRAW mm, mm/imm8',
'PSRAD mm, mm/imm8',
'PSRLQ mm, mm/imm8',
'PSRLW mm, mm/imm8',
'PSRLD mm, mm/imm8',
'PSUBB mm, mm',
'PSUBW mm, mm',
'PSUBD mm, mm',
'PSUBSB mm, mm',
'PSUBSW mm, mm',
'PSUBUSB mm, mm',
'PSUBUSW mm, mm',
'PUNPCKHBW mm, mm',
'PUNPCKHWD mm, mm',
'PUNPCKHDQ mm, mm',
'PUNPCKLBW mm, mm',
'PUNPCKLWD mm, mm',
'PUNPCKLDQ mm, mm',
'PXOR mm, mm',
'EMMS',

#############################################################################
# Source: http://www.amd.com/us-en/assets/content_type/white_papers_and_tech_docs/25112.PDF

# 3DNow!
'PAVGUSB mm, mm',
'PF2ID mm, mm',
'PFACC mm, mm',
'PFADD mm, mm',
'PFCMPEQ mm, mm',
'PFCMPGE mm, mm',
'PFCMPGT mm, mm',
'PFMAX mm, mm',
'PFMIN mm, mm',
'PFMUL mm, mm',
'PFRCP mm, mm',
'PFRCPIT1 mm, mm',
'PFRCPIT2 mm, mm',
'PFRSQIT1 mm, mm',
'PFRSQRT mm, mm',
'PFSUB mm, mm',
'PFSUBR mm, mm',
'PI2FD mm, mm',
'PMULHRW mm, mm',
#'PREFETCH mem8',
#'PREFETCHW mem8',
'FEMMS',

# 3DNow! Extensions
'PF2IW mm, mm',
'PFNACC mm, mm',
'PFPNACC mm, mm',
'PI2FW mm, mm',
'PSWAPD mm, mm',

#############################################################################
# Integer and general-purpose instructions
# Source: http://docs.sun.com/app/docs/doc/817-5477/6mkuavhri?a=view

# Data Transfer Instructions
'BSWAP r',

'CBW',  # al, ax
'CDQ',  # eax, edx:eax
'CDQE', # eax, rax
'CQO',  # rax, rdx:rax
'CWD',  # ax, dx:ax
'CWDE', # ax, eax

#'CMOVA r, r',  # no point in duplicate work, all the cmov variants are the same speed
#'CMOVAE r, r',
#'CMOVB r, r',
#'CMOVBE r, r',
#'CMOVC r, r',
#'CMOVE r, r',
#'CMOVG r, r',
#'CMOVGE r, r',
#'CMOVL r, r',
#'CMOVLE r, r',
#'CMOVNA r, r',
#'CMOVNAE r, r',
#'CMOVNB r, r',
#'CMOVNBE r, r',
#'CMOVNC r, r',
#'CMOVNE r, r',
#'CMOVNG r, r',
#'CMOVNGE r, r',
#'CMOVNL r, r',
#'CMOVNLE r, r',
#'CMOVNO r, r',
#'CMOVNP r, r',
#'CMOVNS r, r',
#'CMOVNZ r, r',
#'CMOVO r, r',
#'CMOVP r, r',
#'CMOVPE r, r', #? problem compiling
#'CMOVPO r, r', #?
#'CMOVS r, r',
'CMOVZ r, r',

'CMPXCHG r, r',
#'CMPXCHG8B',
'MOV r, r',
#'MOVABS',
'MOVSX r64, r32',
#'MOVZX r32, r16',
#'POP',
#'POPA',
#'POPAD',
#'PUSH',
#'PUSHA',
#'PUSHAD',
'XADD r, r',
'XCHG r, r',

# Binary Arithmetic Instructions
'ADC r, r',
'ADD r, r',
'CMP r, r',
'DEC r',
'DIV r',  # from dx:ax into dx and ax
'IDIV r', # from dx:ax into dx and ax
'IMUL r, r', # from ax into dx:ax
'INC r',
'MUL r',  # from ax into dx:ax
'NEG r',
'SBB r, r',
'SUB r, r',

# Decimal Arithmetic Instructions
# note: not available in 64-bit
#'AAA', # ax
#'AAD', # ax
#'AAM', # ax
#'AAS', # ax
#'DAA', # ax
#'DAS', # ax

# Logical Instructions
'AND r, r',
'NOT r',
'OR r, r',
'XOR r, r',

# Shift and Rotate Instructions
'RCL r, imm8',
'RCR r, imm8',
'ROL r, imm8',
'ROR r, imm8',
'SAL r, imm8',
'SAR r, imm8',
'SHL r, imm8',
'SHLD r, r, imm8',
'SHR r, imm8',
'SHRD r, r, imm8',

# Bit and Byte Instructions
'BSF r, r',
'BSR r, r',
'BT r, r',
'BTC r, r',
'BTR r, r',
'BTS r, r',
#'SETA', # SET* r8
#'SETAE',
#'SETB',
#'SETBE',
#'SETC',
#'SETE',
#'SETG',
#'SETGE',
#'SETL',
#'SETLE',
#'SETNA',
#'SETNAE',
#'SETNB',
#'SETNBE',
#'SETNC',
#'SETNE',
#'SETNG',
#'SETNGE',
#'SETNL',
#'SETNLE',
#'SETNO',
#'SETNP',
#'SETNS',
#'SETNZ',
#'SETO',
#'SETP',
#'SETPE',
#'SETPO',
#'SETS',
#'SETZ',
'TEST r, r',

# Control Transfer Instructions
#'BOUND',
#'CALL',
#'ENTER',
#'INT',
#'INTO',
#'IRET',
#'JA',
#'JAE',
#'JB',
#'JBE',
#'JC',
#'JCXZ',
#'JE',
#'JECXZ',
#'JG',
#'JGE',
#'JL',
#'JLE',
#'JMP',
#'JNAE',
#'JNB',
#'JNBE',
#'JNC',
#'JNE',
#'JNG',
#'JNGE',
#'JNL',
#'JNLE',
#'JNO',
#'JNP',
#'JNS',
#'JNZ',
#'JO',
#'JP',
#'JPE',
#'JPO',
#'JS',
#'JZ',
#'CALL',
#'LEAVE',
#'LOOP',
#'LOOPE',
#'LOOPNE',
#'LOOPNZ',
#'LOOPZ',
#'RET',
#'RET',

# String Instructions
#'CMPS',
#'CMPSB',
#'CMPSD',
#'CMPSW',
#'LODS',
#'LODSB',
#'LODSD',
#'LODSW',
#'MOVS',
#'MOVSB',
#'MOVSD',
#'MOVSW',
#'REP',
#'REPNE',
#'REPNZ',
#'REPE',
#'REPZ',
#'SCAS',
#'SCASB',
#'SCASD',
#'SCASW',
#'STOS',
#'STOSB',
#'STOSD',
#'STOSW',

# I/O Instructions
#'IN',
#'INS',
#'INSB',
#'INSD',
#'INSW',
#'OUT',
#'OUTS',
#'OUTSB',
#'OUTSD',
#'OUTSW',

# Flag Control (EFLAG) Instructions
'CLC',
'CLD',
#'CLI',
'CMC',
'LAHF', # flags, ax
#'POPF',
#'POPFL',
#'PUSHF',
#'PUSHFL',
'SAHF', # ax, flags
'STC',
'STD',
#'STI',

# Segment Register Instructions
#'LDS',
#'LES',
#'LFS',
#'LGS',
#'LSS',

# Miscellaneous Instructions
#'CPUID',
#'LEA r, mem',
#'NOP',
#'UD2',
#'XLAT',
#'XLATB',
'RDTSC'

#############################################################################
# Floating-point instructions for x87

# TODO

 );

# instructions whose individual latencies can't be measured, but can be measured in pairs
@instruction_paired_opposites = map lc,
(
'MOVD xmm, r32',         'MOVD r32, xmm',
'MOVD mm, r32',          'MOVD r32, mm',
'MOVDQ2Q mm, xmm',       'MOVQ2DQ xmm, mm',
'PEXTRW r32, xmm, imm8', 'PINSRW xmm, r32, imm8',
'PEXTRW r32, mm, imm8',  'PINSRW mm, r32, imm8',
'PEXTRB r32, xmm, imm8', 'PINSRB xmm, r32, imm8',
'PEXTRD r32, xmm, imm8', 'PINSRD xmm, r32, imm8',
'PEXTRQ r64, xmm, imm8', 'PINSRQ xmm, r64, imm8',
'CVTPD2PI mm, xmm',      'CVTPI2PD xmm, mm',
'CVTSD2SI r32, xmm',     'CVTSI2SD xmm, r32',
'CVTPS2PI mm, xmm',      'CVTPI2PS xmm, mm',
'CVTSS2SI r32, xmm',     'CVTSI2SS xmm, r32',
'CVTTPD2PI mm, xmm',     'CVTPI2PD xmm, mm',
'CVTTSD2SI r32, xmm',    'CVTSI2SD xmm, r32',
'CVTTPS2PI mm, xmm',     'CVTPI2PS xmm, mm',
'CVTTSS2SI r32, xmm',    'CVTSI2SS xmm, r32',
);

1;
